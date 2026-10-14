@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemorySeasonalRemittanceAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.SeasonalRemittanceAssignmentStore = RevenueCycle.newMemorySeasonalRemittanceAssignmentStore()
        let item = RevenueCycle.newSeasonalRemittanceAssignment("code-420", label: "label-62")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
