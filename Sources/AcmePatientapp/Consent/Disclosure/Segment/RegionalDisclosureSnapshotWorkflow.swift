import AcmePlatform
import Foundation

extension Consent {
    /// Moves regional disclosure snapshots through their life cycle and keeps a journal of what it did.
    final class RegionalDisclosureSnapshotService {
        var store: any RegionalDisclosureSnapshotStore
        var validator: RegionalDisclosureSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalDisclosureSnapshotStore, validator: RegionalDisclosureSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("regional disclosure snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalDisclosureSnapshotStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional disclosure snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalDisclosureSnapshotStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newRegionalDisclosureSnapshotService(_ store: any RegionalDisclosureSnapshotStore, clock: any Kit.Clocks.Clock) -> RegionalDisclosureSnapshotService {
        return RegionalDisclosureSnapshotService(
            store: store,
            validator: defaultRegionalDisclosureSnapshotValidator(),
            clock: clock,
            journal: []
        )
    }
}
