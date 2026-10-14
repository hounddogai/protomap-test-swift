import AcmePlatform
import Foundation

extension Consent {
    /// Moves weighted disclosure snapshots through their life cycle and keeps a journal of what it did.
    final class WeightedDisclosureSnapshotCoordinator {
        var store: any WeightedDisclosureSnapshotStore
        var validator: WeightedDisclosureSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedDisclosureSnapshotEngine

        init(store: any WeightedDisclosureSnapshotStore, validator: WeightedDisclosureSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedDisclosureSnapshotEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted disclosure snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedDisclosureSnapshotStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted disclosure snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedDisclosureSnapshotStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted disclosure snapshot \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newWeightedDisclosureSnapshotCoordinator(_ store: any WeightedDisclosureSnapshotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WeightedDisclosureSnapshotCoordinator {
        return WeightedDisclosureSnapshotCoordinator(
            store: store,
            validator: defaultWeightedDisclosureSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedDisclosureSnapshotEngine(flags)
        )
    }
}
