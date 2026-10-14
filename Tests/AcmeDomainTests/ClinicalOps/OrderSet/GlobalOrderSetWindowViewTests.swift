@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalOrderSetWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newGlobalOrderSetWindow("code-103", name: "name-137")
        let view = ClinicalOps.toGlobalOrderSetWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toGlobalOrderSetWindowViews([item, item]).count == 2)
    }
}
