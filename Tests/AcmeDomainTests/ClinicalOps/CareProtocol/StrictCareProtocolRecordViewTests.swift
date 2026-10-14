@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictCareProtocolRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newStrictCareProtocolRecord("code-633", title: "title-372")
        let view = ClinicalOps.toStrictCareProtocolRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toStrictCareProtocolRecordViews([item, item]).count == 2)
    }
}
