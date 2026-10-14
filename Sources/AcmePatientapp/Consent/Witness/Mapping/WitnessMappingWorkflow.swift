import AcmePlatform
import Foundation

extension Consent {
    /// Moves witness mappings through their life cycle and keeps a journal of what it did.
    final class WitnessMappingCoordinator {
        var store: any WitnessMappingStore
        var validator: WitnessMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WitnessMappingEngine

        init(store: any WitnessMappingStore, validator: WitnessMappingValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WitnessMappingEngine) {
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
                throw Kit.Failure("witness mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WitnessMappingStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WitnessMappingStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness mapping \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newWitnessMappingCoordinator(_ store: any WitnessMappingStore, clock: any Kit.Clocks.Clock) -> WitnessMappingCoordinator {
        return WitnessMappingCoordinator(
            store: store,
            validator: defaultWitnessMappingValidator(),
            clock: clock,
            journal: [],
            engine: defaultWitnessMappingEngine()
        )
    }
}
