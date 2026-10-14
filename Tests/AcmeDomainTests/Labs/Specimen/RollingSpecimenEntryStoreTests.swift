@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRollingSpecimenEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RollingSpecimenEntryStore = Labs.newMemoryRollingSpecimenEntryStore()
        let item = Labs.newRollingSpecimenEntry("code-894", title: "title-658")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
