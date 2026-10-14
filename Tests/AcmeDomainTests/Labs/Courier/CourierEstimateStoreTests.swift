@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierEstimateStore = Labs.newMemoryCourierEstimateStore()
        let item = Labs.newCourierEstimate("code-533", title: "title-138")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
