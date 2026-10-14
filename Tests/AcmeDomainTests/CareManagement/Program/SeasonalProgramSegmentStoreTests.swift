@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemorySeasonalProgramSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.SeasonalProgramSegmentStore = CareManagement.newMemorySeasonalProgramSegmentStore()
        let item = CareManagement.newSeasonalProgramSegment("code-568", label: "label-266")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
