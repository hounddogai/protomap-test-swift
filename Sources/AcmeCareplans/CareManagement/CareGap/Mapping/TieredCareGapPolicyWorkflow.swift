import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves tiered care gap policies through their life cycle and keeps a journal of what it did.
    final class TieredCareGapPolicyCoordinator {
        var store: any TieredCareGapPolicyStore
        var validator: TieredCareGapPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredCareGapPolicyEngine

        init(store: any TieredCareGapPolicyStore, validator: TieredCareGapPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredCareGapPolicyEngine) {
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
                throw Kit.Failure("tiered care gap policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredCareGapPolicyStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered care gap policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredCareGapPolicyStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered care gap policy \(code) not found")
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

    static func newTieredCareGapPolicyCoordinator(_ store: any TieredCareGapPolicyStore, clock: any Kit.Clocks.Clock) -> TieredCareGapPolicyCoordinator {
        return TieredCareGapPolicyCoordinator(
            store: store,
            validator: defaultTieredCareGapPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredCareGapPolicyEngine()
        )
    }
}
