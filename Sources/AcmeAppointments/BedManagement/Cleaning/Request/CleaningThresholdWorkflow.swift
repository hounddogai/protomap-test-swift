import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves cleaning thresholds through their life cycle and keeps a journal of what it did.
    final class CleaningThresholdService {
        var store: any CleaningThresholdStore
        var validator: CleaningThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CleaningThresholdEngine

        init(store: any CleaningThresholdStore, validator: CleaningThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CleaningThresholdEngine) {
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
                throw Kit.Failure("cleaning threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CleaningThresholdStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CleaningThresholdStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning threshold \(code) not found")
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

    static func newCleaningThresholdService(_ store: any CleaningThresholdStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CleaningThresholdService {
        return CleaningThresholdService(
            store: store,
            validator: defaultCleaningThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultCleaningThresholdEngine(flags)
        )
    }
}
