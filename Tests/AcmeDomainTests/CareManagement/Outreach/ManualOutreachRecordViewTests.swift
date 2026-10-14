@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualOutreachRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newManualOutreachRecord("code-43", name: "name-621")
        let view = CareManagement.toManualOutreachRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toManualOutreachRecordViews([item, item]).count == 2)
    }
}
