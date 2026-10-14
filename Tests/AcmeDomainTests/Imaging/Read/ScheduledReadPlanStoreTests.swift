@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryScheduledReadPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ScheduledReadPlanStore = Imaging.newMemoryScheduledReadPlanStore()
        let item = Imaging.newScheduledReadPlan("code-259", title: "title-372")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
