@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLenientOutreachThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LenientOutreachThresholdStore = CareManagement.newMemoryLenientOutreachThresholdStore()
        let item = CareManagement.newLenientOutreachThreshold("code-634", name: "name-961")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
