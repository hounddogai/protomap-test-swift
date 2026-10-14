@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierException("code-137", title: "title-437")
        let view = Labs.toCourierExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierExceptionViews([item, item]).count == 2)
    }
}
