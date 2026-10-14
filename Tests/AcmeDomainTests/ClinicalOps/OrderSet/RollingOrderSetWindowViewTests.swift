@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingOrderSetWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRollingOrderSetWindow("code-280", name: "name-968")
        let view = ClinicalOps.toRollingOrderSetWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRollingOrderSetWindowViews([item, item]).count == 2)
    }
}
