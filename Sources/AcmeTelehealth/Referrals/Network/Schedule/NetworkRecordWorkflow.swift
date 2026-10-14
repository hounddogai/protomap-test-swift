import AcmePlatform
import Foundation

extension Referrals {
    /// Moves network records through their life cycle and keeps a journal of what it did.
    final class NetworkRecordCoordinator {
        var store: any NetworkRecordStore
        var validator: NetworkRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any NetworkRecordStore, validator: NetworkRecordValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("network record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(NetworkRecordStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("network record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(NetworkRecordStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newNetworkRecordCoordinator(_ store: any NetworkRecordStore, clock: any Kit.Clocks.Clock) -> NetworkRecordCoordinator {
        return NetworkRecordCoordinator(
            store: store,
            validator: defaultNetworkRecordValidator(),
            clock: clock,
            journal: []
        )
    }
}
