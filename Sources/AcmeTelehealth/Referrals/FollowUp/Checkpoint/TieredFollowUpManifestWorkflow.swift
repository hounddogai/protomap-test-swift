import AcmePlatform
import Foundation

extension Referrals {
    /// Moves tiered follow up manifests through their life cycle and keeps a journal of what it did.
    final class TieredFollowUpManifestService {
        var store: any TieredFollowUpManifestStore
        var validator: TieredFollowUpManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TieredFollowUpManifestStore, validator: TieredFollowUpManifestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered follow up manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredFollowUpManifestStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered follow up manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredFollowUpManifestStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newTieredFollowUpManifestService(_ store: any TieredFollowUpManifestStore, clock: any Kit.Clocks.Clock) -> TieredFollowUpManifestService {
        return TieredFollowUpManifestService(
            store: store,
            validator: defaultTieredFollowUpManifestValidator(),
            clock: clock,
            journal: []
        )
    }
}
