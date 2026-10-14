@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultCareProtocolRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newDefaultCareProtocolRecord("code-947", title: "title-342")
        let view = ClinicalOps.toDefaultCareProtocolRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toDefaultCareProtocolRecordViews([item, item]).count == 2)
    }
}
