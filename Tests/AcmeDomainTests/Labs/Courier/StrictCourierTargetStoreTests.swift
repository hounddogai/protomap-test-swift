@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryStrictCourierTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.StrictCourierTargetStore = Labs.newMemoryStrictCourierTargetStore()
        let item = Labs.newStrictCourierTarget("code-946", name: "name-762")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
