import AcmePlatform
import Foundation

extension Labs {
    /// Moves specimen checkpoints through their life cycle and keeps a journal of what it did.
    final class SpecimenCheckpointDesk {
        var store: any SpecimenCheckpointStore
        var validator: SpecimenCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SpecimenCheckpointEngine

        init(store: any SpecimenCheckpointStore, validator: SpecimenCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SpecimenCheckpointEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SpecimenCheckpointStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SpecimenCheckpointStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen checkpoint \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newSpecimenCheckpointDesk(_ store: any SpecimenCheckpointStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SpecimenCheckpointDesk {
        return SpecimenCheckpointDesk(
            store: store,
            validator: defaultSpecimenCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultSpecimenCheckpointEngine(flags)
        )
    }
}
