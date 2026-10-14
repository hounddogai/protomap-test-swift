@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRegionalCourierWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RegionalCourierWindowStore = Labs.newMemoryRegionalCourierWindowStore()
        let item = Labs.newRegionalCourierWindow("code-42", title: "title-922")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
