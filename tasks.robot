*** Settings ***
Documentation       Template robot main suite.

Library             RPA.Robocloud.Secrets
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.PDF
Library             RPA.Tables
Library             RPA.Salesforce
Library             RPA.Desktop
Library             RPA.Archive
Library             RPA.Dialogs
#Saves the order HTML receipt as a PDF file.
#Saves the screenshot of the ordered robot.
#Embeds the screenshot of the robot to the PDF receipt.
#Creates ZIP archive of the receipts and the images.


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${Order url}    ${Browser url}=    Get Urls from Vault
    Open the intranet website and login    ${Browser url}
    Change to order your robot
    ${orders}=    Get orders    ${Order url}
    ${Folder_name}=    Get User Input

    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]    ${Folder_name}
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file
        ...    ${screenshot}
        ...    ${pdf}
        ...    ${row}[Order number]
        ...    ${Folder_name}
        Go to order another robot
    END
    Create a ZIP file of the receipts    ${Folder_name}
    Close Browser


*** Keywords ***
Get User Input
    ${user_input}=    Add text input    user    Enter the name of the receipt Folder
    ${input}=    Run dialog
    RETURN    ${input.user}

Get Urls from Vault
    ${secret}=    Get Secret    Urls
    RETURN    ${secret}[Orders_url]    ${secret}[Browser_url]

Open the intranet website and login
    [Arguments]    ${Browser url}
    Open Available Browser    ${Browser url}
    Input Text    username    maria
    Input Password    password    thoushallnotpass
    Submit Form
    Wait Until Page Contains Element    id:sales-form

Change to order your robot
    Click Link    xpath=//*[@id="root"]/header/div/ul/li[2]/a

Get orders
    [Arguments]    ${Order url}
    Download    ${Order url}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv
    Log    Found Columns: ${orders.columns}
    RETURN    ${orders}

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${row}
    Select From List By Value    id=head    ${row}[Head]
    Select Radio Button    body    id-body-${row}[Body]
    Input Text    xpath=/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order

    FOR    ${i}    IN RANGE    ${100}
        ${alert}=    Is Element Visible    //div[@class="alert alert-danger"]
        IF    '${alert}'=='True'    Click Button    //button[@id="order"]
        IF    '${alert}'=='False'            BREAK
    END

 #    ${alert}=    Is Element Visible    //div[@role="alert"]
#    IF    '${alert}'=='True'    Click Button    //button[@id="order"]

Store the receipt as a PDF file
    [Arguments]    ${Order number}    ${Folder_name}
    Screenshot    receipt    ${OUTPUT_DIR}${/}${Folder_name}${/}${Order number}.png

Take a screenshot of the robot
    [Arguments]    ${Order number}
    Screenshot    xpath=/html/body/div/div/div[1]/div/div[2]/div/div    ${OUTPUT_DIR}${/}robot${/}${Order number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}    ${Order number}    ${Folder_name}
    ${files}=    Create List
    ...    ${OUTPUT_DIR}${/}${Folder_name}${/}${Order number}.png
    ...    ${OUTPUT_DIR}${/}robot${/}${Order number}.png
    Add Files To Pdf    ${files}    ${OUTPUT_DIR}${/}pdf${/}${Order number}.Pdf

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    [Arguments]    ${Folder_name}
    Archive Folder With Zip    ${OUTPUT_DIR}${/}${Folder_name}    ${OUTPUT_DIR}${/}receipt.zip
