@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryOrderSetDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newPrimaryOrderSetDigest("code-118", title: "title-984")
        let view = ClinicalOps.toPrimaryOrderSetDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toPrimaryOrderSetDigestViews([item, item]).count == 2)
    }
}
