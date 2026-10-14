@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDefaultCensusWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DefaultCensusWindowStore = BedManagement.newMemoryDefaultCensusWindowStore()
        let item = BedManagement.newDefaultCensusWindow("code-166", label: "label-66")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
