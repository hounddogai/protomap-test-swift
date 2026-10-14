import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves legacy task mappings through their life cycle and keeps a journal of what it did.
    final class LegacyTaskMappingService {
        var store: any LegacyTaskMappingStore
        var validator: LegacyTaskMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyTaskMappingEngine

        init(store: any LegacyTaskMappingStore, validator: LegacyTaskMappingValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyTaskMappingEngine) {
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
                throw Kit.Failure("legacy task mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyTaskMappingStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy task mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyTaskMappingStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy task mapping \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newLegacyTaskMappingService(_ store: any LegacyTaskMappingStore, clock: any Kit.Clocks.Clock) -> LegacyTaskMappingService {
        return LegacyTaskMappingService(
            store: store,
            validator: defaultLegacyTaskMappingValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyTaskMappingEngine()
        )
    }
}
