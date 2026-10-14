@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangePreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangePreference("code-481", title: "title-919")
        let view = Labs.toReferenceRangePreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangePreferenceViews([item, item]).count == 2)
    }
}
