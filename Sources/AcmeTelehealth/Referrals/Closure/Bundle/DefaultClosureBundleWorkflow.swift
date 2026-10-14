import AcmePlatform
import Foundation

extension Referrals {
    /// Moves default closure bundles through their life cycle and keeps a journal of what it did.
    final class DefaultClosureBundleCoordinator {
        var store: any DefaultClosureBundleStore
        var validator: DefaultClosureBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultClosureBundleEngine

        init(store: any DefaultClosureBundleStore, validator: DefaultClosureBundleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultClosureBundleEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default closure bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultClosureBundleStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default closure bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultClosureBundleStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default closure bundle \(code) not found")
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
                if item.createdAt > cutoff {
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

    static func newDefaultClosureBundleCoordinator(_ store: any DefaultClosureBundleStore, clock: any Kit.Clocks.Clock) -> DefaultClosureBundleCoordinator {
        return DefaultClosureBundleCoordinator(
            store: store,
            validator: defaultDefaultClosureBundleValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultClosureBundleEngine()
        )
    }
}
