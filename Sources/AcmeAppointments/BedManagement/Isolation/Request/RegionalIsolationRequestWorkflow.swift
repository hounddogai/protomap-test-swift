import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves regional isolation requests through their life cycle and keeps a journal of what it did.
    final class RegionalIsolationRequestCoordinator {
        var store: any RegionalIsolationRequestStore
        var validator: RegionalIsolationRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalIsolationRequestEngine

        init(store: any RegionalIsolationRequestStore, validator: RegionalIsolationRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalIsolationRequestEngine) {
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
                throw Kit.Failure("regional isolation request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalIsolationRequestStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional isolation request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalIsolationRequestStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional isolation request \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newRegionalIsolationRequestCoordinator(_ store: any RegionalIsolationRequestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalIsolationRequestCoordinator {
        return RegionalIsolationRequestCoordinator(
            store: store,
            validator: defaultRegionalIsolationRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalIsolationRequestEngine(flags)
        )
    }
}
