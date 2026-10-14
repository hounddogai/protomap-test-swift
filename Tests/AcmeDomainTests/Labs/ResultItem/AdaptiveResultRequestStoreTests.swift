@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAdaptiveResultRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AdaptiveResultRequestStore = Labs.newMemoryAdaptiveResultRequestStore()
        let item = Labs.newAdaptiveResultRequest("code-155", label: "label-457")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
