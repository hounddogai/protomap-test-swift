@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionBaselineStore = Labs.newMemoryAccessionBaselineStore()
        let item = Labs.newAccessionBaseline("code-258", name: "name-186")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
