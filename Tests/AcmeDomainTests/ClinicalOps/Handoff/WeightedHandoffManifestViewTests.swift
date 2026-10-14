@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedHandoffManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newWeightedHandoffManifest("code-873", title: "title-264")
        let view = ClinicalOps.toWeightedHandoffManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toWeightedHandoffManifestViews([item, item]).count == 2)
    }
}
