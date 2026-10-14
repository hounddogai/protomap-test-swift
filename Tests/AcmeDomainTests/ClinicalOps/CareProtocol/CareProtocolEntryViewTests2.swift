@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newCareProtocolEntry("code-540", label: "label-807")
        let view = ClinicalOps.toCareProtocolEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toCareProtocolEntryViews([item, item]).count == 2)
    }
}
