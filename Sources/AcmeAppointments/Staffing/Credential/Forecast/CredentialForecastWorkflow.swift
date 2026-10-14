import AcmePlatform
import Foundation

extension Staffing {
    /// Moves credential forecasts through their life cycle and keeps a journal of what it did.
    final class CredentialForecastService {
        var store: any CredentialForecastStore
        var validator: CredentialForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CredentialForecastStore, validator: CredentialForecastValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CredentialForecastStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CredentialForecastStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newCredentialForecastService(_ store: any CredentialForecastStore, clock: any Kit.Clocks.Clock) -> CredentialForecastService {
        return CredentialForecastService(
            store: store,
            validator: defaultCredentialForecastValidator(),
            clock: clock,
            journal: []
        )
    }
}
