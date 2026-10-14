import AcmePlatform
import Foundation

extension Referrals {
    /// Moves legacy slot records through their life cycle and keeps a journal of what it did.
    final class LegacySlotRecordManager {
        var store: any LegacySlotRecordStore
        var validator: LegacySlotRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacySlotRecordEngine

        init(store: any LegacySlotRecordStore, validator: LegacySlotRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacySlotRecordEngine) {
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
                throw Kit.Failure("legacy slot record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacySlotRecordStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy slot record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacySlotRecordStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy slot record \(code) not found")
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

    static func newLegacySlotRecordManager(_ store: any LegacySlotRecordStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LegacySlotRecordManager {
        return LegacySlotRecordManager(
            store: store,
            validator: defaultLegacySlotRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacySlotRecordEngine(flags)
        )
    }
}
