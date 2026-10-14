@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTaskMapping("code-692", title: "title-116")
        let view = ClinicalOps.toTaskMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTaskMappingViews([item, item]).count == 2)
    }
}
