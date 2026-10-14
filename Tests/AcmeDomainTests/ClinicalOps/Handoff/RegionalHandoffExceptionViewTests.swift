@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalHandoffExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRegionalHandoffException("code-483", name: "name-376")
        let view = ClinicalOps.toRegionalHandoffExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRegionalHandoffExceptionViews([item, item]).count == 2)
    }
}
