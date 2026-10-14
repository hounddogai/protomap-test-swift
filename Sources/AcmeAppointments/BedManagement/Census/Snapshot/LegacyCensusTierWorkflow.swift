import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves legacy census tiers through their life cycle and keeps a journal of what it did.
    final class LegacyCensusTierService {
        var store: any LegacyCensusTierStore
        var validator: LegacyCensusTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyCensusTierEngine

        init(store: any LegacyCensusTierStore, validator: LegacyCensusTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyCensusTierEngine) {
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
                throw Kit.Failure("legacy census tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyCensusTierStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy census tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyCensusTierStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy census tier \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newLegacyCensusTierService(_ store: any LegacyCensusTierStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LegacyCensusTierService {
        return LegacyCensusTierService(
            store: store,
            validator: defaultLegacyCensusTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyCensusTierEngine(flags)
        )
    }
}
