import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves default claim rollups through their life cycle and keeps a journal of what it did.
    final class DefaultClaimRollupService {
        var store: any DefaultClaimRollupStore
        var validator: DefaultClaimRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultClaimRollupEngine

        init(store: any DefaultClaimRollupStore, validator: DefaultClaimRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultClaimRollupEngine) {
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
                throw Kit.Failure("default claim rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultClaimRollupStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default claim rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultClaimRollupStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default claim rollup \(code) not found")
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

    static func newDefaultClaimRollupService(_ store: any DefaultClaimRollupStore, clock: any Kit.Clocks.Clock) -> DefaultClaimRollupService {
        return DefaultClaimRollupService(
            store: store,
            validator: defaultDefaultClaimRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultClaimRollupEngine()
        )
    }
}
