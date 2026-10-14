@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenPreferenceStore = Labs.newMemorySpecimenPreferenceStore()
        let item = Labs.newSpecimenPreference("code-460", label: "label-23")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
