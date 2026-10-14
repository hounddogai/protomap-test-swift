@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalHandoffManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRegionalHandoffManifest("code-806", label: "label-190")
        let view = ClinicalOps.toRegionalHandoffManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRegionalHandoffManifestViews([item, item]).count == 2)
    }
}
