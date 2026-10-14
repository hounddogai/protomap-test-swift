@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAdaptiveResultPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AdaptiveResultPolicyStore = Labs.newMemoryAdaptiveResultPolicyStore()
        let item = Labs.newAdaptiveResultPolicy("code-522", label: "label-464")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
