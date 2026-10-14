import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves legacy discharge plan digests through their life cycle and keeps a journal of what it did.
    final class LegacyDischargePlanDigestManager {
        var store: any LegacyDischargePlanDigestStore
        var validator: LegacyDischargePlanDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LegacyDischargePlanDigestStore, validator: LegacyDischargePlanDigestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy discharge plan digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyDischargePlanDigestStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy discharge plan digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyDischargePlanDigestStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newLegacyDischargePlanDigestManager(_ store: any LegacyDischargePlanDigestStore, clock: any Kit.Clocks.Clock) -> LegacyDischargePlanDigestManager {
        return LegacyDischargePlanDigestManager(
            store: store,
            validator: defaultLegacyDischargePlanDigestValidator(),
            clock: clock,
            journal: []
        )
    }
}
