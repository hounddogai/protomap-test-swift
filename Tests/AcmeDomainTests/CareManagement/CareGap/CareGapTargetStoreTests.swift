@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapTargetStore = CareManagement.newMemoryCareGapTargetStore()
        let item = CareManagement.newCareGapTarget("code-467", name: "name-295")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
