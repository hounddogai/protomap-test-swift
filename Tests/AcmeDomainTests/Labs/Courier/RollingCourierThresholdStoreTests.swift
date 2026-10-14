@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRollingCourierThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RollingCourierThresholdStore = Labs.newMemoryRollingCourierThresholdStore()
        let item = Labs.newRollingCourierThreshold("code-71", title: "title-488")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
