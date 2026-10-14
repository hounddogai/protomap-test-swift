import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves order set digests through their life cycle and keeps a journal of what it did.
    final class OrderSetDigestCoordinator {
        var store: any OrderSetDigestStore
        var validator: OrderSetDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OrderSetDigestEngine

        init(store: any OrderSetDigestStore, validator: OrderSetDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OrderSetDigestEngine) {
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
                throw Kit.Failure("order set digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OrderSetDigestStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OrderSetDigestStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set digest \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newOrderSetDigestCoordinator(_ store: any OrderSetDigestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> OrderSetDigestCoordinator {
        return OrderSetDigestCoordinator(
            store: store,
            validator: defaultOrderSetDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultOrderSetDigestEngine(flags)
        )
    }
}
