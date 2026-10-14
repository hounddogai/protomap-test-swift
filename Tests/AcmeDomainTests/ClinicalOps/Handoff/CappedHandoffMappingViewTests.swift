@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedHandoffMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newCappedHandoffMapping("code-612", name: "name-518")
        let view = ClinicalOps.toCappedHandoffMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toCappedHandoffMappingViews([item, item]).count == 2)
    }
}
