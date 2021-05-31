*** Settings ***
Documentation   Orders robots from RobotSpareBin Industries Inc.
...             Saves the order HTML receipt as a PDF file.
...             Saves the screenshot of the ordered robot.
...             Embeds the screenshot of the robot to the PDF receipt.
...             Creates ZIP archive of the receipts and the images.
Library         RPA.Browser.Selenium
Library         OperatingSystem
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.HTTP
Library         RPA.Archive
Library         Dialogs
Library         RPA.Robocloud.Secrets
Library         RPA.core.notebook

*** Keywords ***
Open Website
    &{website}=  Get Secret    websitedetails
    Open Available Browser  ${website}[url]

*** Keywords ***
Click Popup when Visible
    Click Button When Visible    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1] 

*** Keywords ***
Get Orders CSV
    ${file_url}=  Get Value From User  Please enter the csv file url  https://robotsparebinindustries.com/orders.csv  
    Download  ${file_url}  orders.csv  overwrite=True
    ${orders}=  Read Table From Csv    Orders.csv  header=True
    Return From Keyword  ${orders}
    Sleep  2 seconds

*** Keywords ***
Fill the form
    [Arguments]    ${Order}
    Wait Until Element Is Visible    xpath://*[@id="head"]
    Select From List By Index   head  ${Order}[Head]
    Click Element  id-body-${Order}[Body]
    Input Text  css:input[placeholder='Enter the part number for the legs']  ${Order}[Legs]
    Input Text  address  ${Order}[Address]

*** Keywords ***
Preview the robot
    Click Element    xpath://*[@id="preview"]
    Sleep    2 seconds

*** Keywords ***
Submit the order
    FOR    ${i}    IN RANGE    1000
        Click Element    xpath://*[@id="order"]
        ${order_status}    Run Keyword And Return Status    Element Should Be Visible     css:div[id="receipt"]    
        Exit For Loop If    ${order_status}==True
    END
    
*** Keywords ***
Create the receipt as a PDF file
    [Arguments]    ${order number}
    Wait Until Element Is Visible    css:div[id="receipt"]    
    ${reciept}     Get Element Attribute    css:div[id="receipt"]    outerHTML
    Sleep    2 seconds
    Html To Pdf    ${reciept}   output/receipts/${order number}.pdf
    ${pdf}    Join Path    output    receipts    ${order number}.pdf
    [Return]    ${pdf}   

*** Keywords ***
Take a screenshot
    [Arguments]    ${order number}
    ${screenshot}    Capture Element Screenshot    xpath://*[@id="robot-preview-image"]    screenshots/${order number}.png
    [Return]    ${screenshot}

*** Keywords ***    
Add the screenshot to the PDF file 
       [Arguments]    ${screenshot}    ${pdf}
       ${files}    Create List    ${screenshot}    ${pdf}
       Add Files To Pdf    ${files}    ${pdf}   

*** Keywords ***   
Go to order another robot
    Click Element    xpath://*[@id="order-another"]

*** Keywords ***   
Create ZIP file of receipts
    Archive Folder With Zip    output/receipts    output/receipts.zip
    
*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${orders}=    Get Orders CSV
    Open website
    FOR    ${Order}    IN    @{orders}
        Click Popup when Visible
        Fill the form    ${Order}
        Preview the robot
        Submit the order
        ${pdf}=    Create the receipt as a PDF file    ${Order}[Order number]        
        ${screenshot}=    Take a screenshot    ${Order}[Order number]
        Add the screenshot to the PDF file     ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create ZIP file of receipts