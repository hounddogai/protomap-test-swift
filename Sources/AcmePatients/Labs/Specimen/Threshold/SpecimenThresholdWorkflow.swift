import AcmePlatform
import Foundation

extension Labs {
    /// Moves specimen thresholds through their life cycle and keeps a journal of what it did.
    final class SpecimenThresholdDesk {
        var store: any SpecimenThresholdStore
        var validator: SpecimenThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SpecimenThresholdEngine

        init(store: any SpecimenThresholdStore, validator: SpecimenThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SpecimenThresholdEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SpecimenThresholdStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SpecimenThresholdStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen threshold \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newSpecimenThresholdDesk(_ store: any SpecimenThresholdStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SpecimenThresholdDesk {
        return SpecimenThresholdDesk(
            store: store,
            validator: defaultSpecimenThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultSpecimenThresholdEngine(flags)
        )
    }
}
