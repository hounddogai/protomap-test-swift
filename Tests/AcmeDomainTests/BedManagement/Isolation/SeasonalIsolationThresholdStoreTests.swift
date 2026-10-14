@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemorySeasonalIsolationThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.SeasonalIsolationThresholdStore = BedManagement.newMemorySeasonalIsolationThresholdStore()
        let item = BedManagement.newSeasonalIsolationThreshold("code-638", label: "label-788")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
