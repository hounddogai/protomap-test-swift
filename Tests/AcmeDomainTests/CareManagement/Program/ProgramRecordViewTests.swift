@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newProgramRecord("code-37", label: "label-989")
        let view = CareManagement.toProgramRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toProgramRecordViews([item, item]).count == 2)
    }
}
