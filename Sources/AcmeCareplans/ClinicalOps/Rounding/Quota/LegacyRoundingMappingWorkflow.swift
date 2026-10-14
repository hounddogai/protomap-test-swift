import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves legacy rounding mappings through their life cycle and keeps a journal of what it did.
    final class LegacyRoundingMappingService {
        var store: any LegacyRoundingMappingStore
        var validator: LegacyRoundingMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LegacyRoundingMappingStore, validator: LegacyRoundingMappingValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy rounding mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyRoundingMappingStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy rounding mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyRoundingMappingStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newLegacyRoundingMappingService(_ store: any LegacyRoundingMappingStore, clock: any Kit.Clocks.Clock) -> LegacyRoundingMappingService {
        return LegacyRoundingMappingService(
            store: store,
            validator: defaultLegacyRoundingMappingValidator(),
            clock: clock,
            journal: []
        )
    }
}
