@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAdaptiveSpecimenTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AdaptiveSpecimenTemplateStore = Labs.newMemoryAdaptiveSpecimenTemplateStore()
        let item = Labs.newAdaptiveSpecimenTemplate("code-866", title: "title-58")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
