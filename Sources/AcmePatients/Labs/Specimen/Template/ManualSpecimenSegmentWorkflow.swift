import AcmePlatform
import Foundation

extension Labs {
    /// Moves manual specimen segments through their life cycle and keeps a journal of what it did.
    final class ManualSpecimenSegmentCoordinator {
        var store: any ManualSpecimenSegmentStore
        var validator: ManualSpecimenSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualSpecimenSegmentEngine

        init(store: any ManualSpecimenSegmentStore, validator: ManualSpecimenSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualSpecimenSegmentEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual specimen segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualSpecimenSegmentStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual specimen segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualSpecimenSegmentStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual specimen segment \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newManualSpecimenSegmentCoordinator(_ store: any ManualSpecimenSegmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ManualSpecimenSegmentCoordinator {
        return ManualSpecimenSegmentCoordinator(
            store: store,
            validator: defaultManualSpecimenSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualSpecimenSegmentEngine(flags)
        )
    }
}
