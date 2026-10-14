@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierManifestStore = Labs.newMemoryCourierManifestStore()
        let item = Labs.newCourierManifest("code-254", title: "title-272")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
